pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    component hashes[2**n - 1];
    for (var i=0; i<(2**n)-1; i++) {
      hashes[i] = Poseidon(2);
    }

    // hash leaves
    for (var i=0; i<(2**n)/2; i++) {
      hashes[i].inputs[0] <== leaves[i * 2];
      hashes[i].inputs[1] <== leaves[i * 2 + 1];
    }

    // hash next level
    var offset = 0;
    for (var i=(2**n / 2); i < ((2**n)/2) + ((2**n)/2) - 1; i++) {
      hashes[i].inputs[0] <== leaves[offset * 2].out;
      hashes[i].inputs[1] <== leaves[offset * 2 + 1].out;
      offset++;
    }


    root <== hashes[2**n-1].out;
}

template HashLeftRight() {
  signal input left;
  signal input right;
  signal output hash;

  component poseidon = Poseidon(2);
  poseidon.inputs[0] <== left;
  poseidon.inputs[1] <== right;

  hash <== poseidon.out;
}

// DualMux template is from the tornadocash repo
// refer to: https://github.com/tornadocash/tornado-core/blob/master/circuits/merkleTree.circom

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component hashes[n];
    component selectors[n];

    for (var i=0; i < n; i++) {
      selectors[i] = DualMux();
      selectors[i].in[0] <== i == 0 ? leaf : hashes[i - 1].hash;
      selectors[i].in[1] <== path_elements[i];
      selectors[i].s <== path_index[i];

      hashes[i] = HashLeftRight();
      hashes[i].left <== selectors[i].out[0];
      hashes[i].right <== selectors[i].out[1];
    }

    root <== hashes[n - 1].hash;
}
