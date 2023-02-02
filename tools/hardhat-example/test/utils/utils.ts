// usage: await sleep(msToSleep);
export const sleep = (milliseconds: number) => {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

export enum PromiseStatus {
  PENDING = "pending",
  FULFILLED = "fulfilled",
  REJECTED = "rejected"
}