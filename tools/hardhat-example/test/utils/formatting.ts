export function removeLeadingZeros(decimal: number) {
  while (decimal && (decimal & 1) === 0) decimal = decimal >>> 1;
  return '0x' + decimal.toString(16);
}