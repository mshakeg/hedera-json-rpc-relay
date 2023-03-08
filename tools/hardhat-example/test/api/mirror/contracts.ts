import axios from 'axios';
import hre from "hardhat";

export const getContractInfo = async (idOrEvmAlias: string) => {
  try {
    const mirrorPath =
      hre.config.networks[hre.network.name].metadata.mirrorPath;

    const response = await axios.get(`${mirrorPath}/contracts/${idOrEvmAlias}`);

    return {
      ok: true,
      data: response.data
    }

  } catch (e) {
    return {
      ok: false,
      error: e,
      result: null,
    };
  }
};
