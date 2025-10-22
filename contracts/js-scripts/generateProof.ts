import { Barretenberg, Fr, UltraHonkBackend } from "@aztec/bb.js"; 
import { ethers } from "ethers";
import { Noir } from "@noir-lang/noir_js";
import fs from "fs";
import path from "path";
import { merkleTree } from "./merkleTree.js";

const circuit = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../../circuits/target/circuits.json"), "utf-8"));

export default async function generateProof(): Promise<string> {
    const bb = await Barretenberg.new ();
    const cliInputs = process.argv.slice(2);

    const nullifier = Fr.fromString(cliInputs[0]);
    const secret = Fr.fromString(cliInputs[1]);
    const recipient = cliInputs[2];
    const leaves = cliInputs.slice(3);
    
    const nullifierHash = await bb.poseidon2Hash([nullifier]);
    const commitment = await bb.poseidon2Hash([nullifier, secret]);

    const tree = await merkleTree(leaves);
    const treeProofData = tree.proof(commitment.toString());

    const root = treeProofData.root;
    const merkle_proof_paths = treeProofData.pathElements.map((el: any) => el.toString());

    const is_even_paths = treeProofData.pathIndices.map((i: any) => i % 2 === 0);
    const noir = new Noir(circuit);
    const honk = new UltraHonkBackend(circuit.bytecode, {threads: 1});

    const input = {
        root: root.toString(),
        nullifier_hash: nullifierHash.toString(),
        recipient: recipient,
        nullifier: nullifier.toString(),
        secret: secret.toString(),
        merkle_proof: merkle_proof_paths,
        isValid: is_even_paths,

    }

    const originalLog = console.log;
    console.log = () => {};

    const { witness } = await noir.execute(input);
    const proofData = await honk.generateProof(witness, {keccak: true});

    const proof = proofData.proof;
    const publicInputs = proofData.publicInputs;
    const publicInputsAsBytes32 = publicInputs.map((input: String) => {
        return Fr.fromString(input.toString()).toBuffer();
    });

    console.log = originalLog;
    const result = ethers.utils.defaultAbiCoder.encode(["bytes"], [proof, publicInputsAsBytes32]);
    return result;
}

(async () => {
    try {
        const result = await generateProof();
        process.stdout.write(result);
        process.exit(0);
    } catch (error) {
        console.error("Error generating proof:", error);
        process.exit(1);
    }
})();