export const Accounts: { [key: string]: string } = {

  // local

  // SDK Network Operators:
  "0.0.2": "302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137",

  // testnet & mainnet
  [process.env.TESTNET_OPERATOR_ID || "h_testnet"]: process.env.TESTNET_OPERATOR_PRIVATE_KEY || "", // fallback should never be used
  [process.env.MAINNET_OPERATOR_ID || "h_mainnet"]: process.env.MAINNET_OPERATOR_PRIVATE_KEY || "",

  // (ECDSA keys)
  "0.0.1002": "0x7f109a9e3b0d8ecfba9cc23a3614433ce0fa7ddcc80f2a8f10b222179a5a80d6",
  "0.0.1003": "0x6ec1f2e7d126a74a1d2ff9e1c5d90b92378c725e506651ff8bb8616a5c724628",
  "0.0.1004": "0xb4d7f7e82f61d81c95985771b8abf518f9328d019c36849d4214b5f995d13814",
  "0.0.1005": "0x941536648ac10d5734973e94df413c17809d6cc5e24cd11e947e685acfbd12ae",
  "0.0.1006": "0x5829cf333ef66b6bdd34950f096cb24e06ef041c5f63e577b4f3362309125863",
  "0.0.1007": "0x8fc4bffe2b40b2b7db7fd937736c4575a0925511d7a0a2dfc3274e8c17b41d20",
  "0.0.1008": "0xb6c10e2baaeba1fa4a8b73644db4f28f4bf0912cceb6e8959f73bb423c33bd84",
  "0.0.1009": "0xfe8875acb38f684b2025d5472445b8e4745705a9e7adc9b0485a05df790df700",
  "0.0.1010": "0xbdc6e0a69f2921a78e9af930111334a41d3fab44653c8de0775572c526feea2d",
  "0.0.1011": "0x3e215c3d2a59626a669ed04ec1700f36c05c9b216e592f58bbfd3d8aa6ea25f9",

  // (Alias ECDSA keys)
  "0.0.1012": "0x105d050185ccb907fba04dd92d8de9e32c18305e097ab41dadda21489a211524",
  "0.0.1013": "0x2e1d968b041d84dd120a5860cee60cd83f9374ef527ca86996317ada3d0d03e7",
  "0.0.1014": "0x45a5a7108a18dd5013cf2d5857a28144beadc9c70b3bdbd914e38df4e804b8d8",
  "0.0.1015": "0x6e9d61a325be3f6675cf8b7676c70e4a004d2308e3e182370a41f5653d52c6bd",
  "0.0.1016": "0x0b58b1bd44469ac9f813b5aeaf6213ddaea26720f0b2f133d08b6f234130a64f",
  "0.0.1017": "0x95eac372e0f0df3b43740fa780e62458b2d2cc32d6a440877f1cc2a9ad0c35cc",
  "0.0.1018": "0x6c6e6727b40c8d4b616ab0d26af357af09337299f09c66704146e14236972106",
  "0.0.1019": "0x5072e7aa1b03f531b4731a32a021f6a5d20d5ddc4e55acbb71ae202fc6f3a26d",
  "0.0.1020": "0x60fe891f13824a2c1da20fb6a14e28fa353421191069ba6b6d09dd6c29b90eff",
  "0.0.1021": "0xeae4e00ece872dd14fb6dc7a04f390563c7d69d16326f2a703ec8e0934060cc7",

  // (ED25519 keys)
  "0.0.1022": "0xa608e2130a0a3cb34f86e757303c862bee353d9ab77ba4387ec084f881d420d4",
  "0.0.1023": "0xbbd0894de0b4ecfa862e963825c5448d2d17f807a16869526bff29185747acdb",
  "0.0.1024": "0x8fd50f886a2e7ed499e7686efd1436b50aa9b64b26e4ecc4e58ca26e6257b67d",
  "0.0.1025": "0x62c966ebd9dcc0fc16a553b2ef5b72d1dca05cdf5a181027e761171e9e947420",
  "0.0.1026": "0x805c9f422fd9a768fdd8c68f4fe0c3d4a93af714ed147ab6aed5f0ee8e9ee165",
  "0.0.1027": "0xabfdb8bf0b46c0da5da8d764316f27f185af32357689f7e19cb9ec3e0f590775",
  "0.0.1028": "0xec299c9f17bb8bdd5f3a21f1c2bffb3ac86c22e84c325e92139813639c9c3507",
  "0.0.1029": "0xcb833706d1df537f59c418a00e36159f67ce3760ce6bf661f11f6da2b11c2c5a",
  "0.0.1030": "0x9b6adacefbbecff03e4359098d084a3af8039ce7f29d95ed28c7ebdb83740c83",
  "0.0.1031": "0x9a07bbdbb62e24686d2a4259dc88e38438e2c7a1ba167b147ad30ac540b0a3cd",
};

export type SdkAccountCredentials = {
  accountId: string;
  privateKey: string;
};

export const SdkAccounts: {
  h_local: SdkAccountCredentials;
  h_testnet: SdkAccountCredentials;
  h_mainnet: SdkAccountCredentials;
} = {
  h_local: {
    accountId: "0.0.2",
    privateKey: "302e020100300506032b65700422042091132178e72057a1d7528025956fe39b0b847f200ab59b2fdd367017f3087137",
  },
  h_testnet: {
    accountId: process.env.TESTNET_OPERATOR_ID!,
    privateKey: process.env.TESTNET_OPERATOR_PRIVATE_KEY!,
  },
  h_mainnet: {
    accountId: process.env.MAINNET_OPERATOR_ID!,
    privateKey: process.env.MAINNET_OPERATOR_PRIVATE_KEY!,
  },
};
