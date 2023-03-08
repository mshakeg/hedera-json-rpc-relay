import hre from "hardhat";
import axios from 'axios';

export const getAccountInfo = async (idOrEvmAlias: string) => {
  try {
    const mirrorPath =
      hre.config.networks[hre.network.name].metadata.mirrorPath || '';

      const response = await axios.get(`${mirrorPath}/accounts/${idOrEvmAlias}`);

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
