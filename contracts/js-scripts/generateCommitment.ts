import { Barretenberg, Fr } from "@aztec/bb.js" 
import { ethers } from "ethers";


export default async function generateCommitment(): Promise <string> {
    const bb = await Barretenberg.new();

    const nullifier: Fr = Fr.random(); 
    const secret: Fr = Fr.random(); 

    const commitment: Fr = await bb.poseidon2Hash([nullifier, secret]);

    const result = ethers.utils.defaultAbiCoder.encode(["bytes32", "bytes32", "bytes32"], [commitment.toBuffer(), nullifier.toBuffer(), secret.toBuffer()]);

    return result;
}

(async () => {
    try {
        const result = await generateCommitment();
        process.stdout.write(result);
        process.exit(0);
    } catch(error) {
        console.error("Error generating commitment:", error);
        process.exit(1);
    };
})();