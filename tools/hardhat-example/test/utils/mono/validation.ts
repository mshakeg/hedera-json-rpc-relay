import { utils } from "ethers";

export class Validation {
  static isValidUrl(url: string) {
    return (
      !!url &&
      (/(?:^|\s)((https?:\/\/)?(?:localhost|[\w-]+(?:\.[\w-]+)+)(:\d+)?(\/\S*)?)/.test(url) ||
        /(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})/gi.test(
          url
        ))
    );
  }

  // source: https://stackoverflow.com/a/175787/10261711
  static isValidRealNum(num: number) {
    return !isNaN(num) && !isNaN(parseFloat(String(num)));
  }

  static isValidNum(stringNum: string) {
    return /^\d+$/.test(stringNum);
  }

  static isString(str: string) {
    return typeof str === "string";
  }

  static isArray(arr: []) {
    return Array.isArray(arr);
  }

  static isValidArray(arr: []) {
    return Array.isArray(arr) && arr.length > 0;
  }

  static isValidHederaId(id: string) {
    return typeof id === "string" && id.startsWith("0.0.") && this.isValidNum(id.substring(4));
  }

  static isValidNetwork(network: string) {
    return ["testnet", "mainnet"].includes(network);
  }

  static isValidEvmAddress(address: string) {
    try {
      utils.getAddress(address);

      return true;
    } catch (e) {
      return false;
    }
  }

  static isValidBool(bool: boolean) {
    const boolString = String(bool);

    return boolString === "true" || boolString === "false";
  }
}
