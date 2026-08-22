import { describe, expect, it } from "vitest";
import { validateWeight } from "../src/domain/services/weight-validation.js";

describe("validateWeight", () => {
  it("approves when measured weight is inside tolerance", () => {
    const result = validateWeight(10000, 10040, 0.5);
    expect(result.approved).toBe(true);
    expect(result.differenceGrams).toBe(40);
  });

  it("rejects when measured weight is outside tolerance", () => {
    const result = validateWeight(10000, 10100, 0.5);
    expect(result.approved).toBe(false);
    expect(result.percentageDifference).toBe(1);
  });

  it("uses absolute percentage difference for lighter measured weight", () => {
    const result = validateWeight(10000, 9940, 0.5);
    expect(result.approved).toBe(false);
    expect(result.differenceGrams).toBe(-60);
  });
});
