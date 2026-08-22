export type WeightValidationResult = {
  approved: boolean;
  differenceGrams: number;
  percentageDifference: number;
};

export function validateWeight(
  expectedWeightGrams: number,
  measuredWeightGrams: number,
  tolerancePercentage: number
): WeightValidationResult {
  if (expectedWeightGrams <= 0) {
    return {
      approved: measuredWeightGrams === 0,
      differenceGrams: measuredWeightGrams - expectedWeightGrams,
      percentageDifference: measuredWeightGrams === 0 ? 0 : 100
    };
  }

  const differenceGrams = measuredWeightGrams - expectedWeightGrams;
  const percentageDifference = Math.abs(differenceGrams) / expectedWeightGrams * 100;

  return {
    approved: percentageDifference <= tolerancePercentage,
    differenceGrams,
    percentageDifference
  };
}
