//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
  uint256[] public hashes; // the Merkle tree in flattened array form
  uint256 public index = 0; // the current index of the first unfilled leaf
  uint256 public root; // the current Merkle root

  constructor() {
    // [assignment] initialize a Merkle tree of 8 with blank leaves
    hashes = new uint256[](15);

    uint256 child_start;
    for (uint256 level = 3; level > 0; --level) {
      uint256 parent_start = child_start + 2**level;

      for (uint256 i = 0; i < 2**(level - 1); ++i) {
        hashes[parent_start + i] = PoseidonT3.poseidon(
          [hashes[child_start + i], hashes[child_start + i + 1]]
        );
      }

      child_start = parent_start;
    }

    root = hashes[hashes.length - 1];
  }

  function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
    // [assignment] insert a hashed leaf into the Merkle tree

    if (index == 8) { revert(); }

    hashes[index] = hashedLeaf;

    uint256 start;
    uint256 current = index;

    for (uint256 level = 3; level > 0; --level) {
      uint256 child = start + current;

      uint256 hash;
      if (child % 2 == 0) {
        hash = PoseidonT3.poseidon([hashes[child], hashes[child + 1]]);
      } else {
        hash = PoseidonT3.poseidon([hashes[child - 1], hashes[child]]);
      }

      start += 2**level;
      current = current / 2;
      hashes[start + current] = hash;

    }

    root = hashes[hashes.length - 1];
    index += 1;

    return index;
  }

  function verify(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[1] memory input
  ) public view returns (bool) {

    // [assignment] verify an inclusion proof and check that the proof root matches current root
    if (input[0] != root || !verifyProof(a, b, c, input)) {
      return false;
    }

    return true;
  }
}
