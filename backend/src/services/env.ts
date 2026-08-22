import dotenv from "dotenv";

dotenv.config();

export const env = {
  port: Number(process.env.PORT ?? 3333),
  jwtSecret: process.env.JWT_SECRET ?? "development-only-secret",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? "7d",
  weightTolerancePercentage: Number(process.env.WEIGHT_TOLERANCE_PERCENTAGE ?? 0.5),
  exitTokenTtlMinutes: Number(process.env.EXIT_TOKEN_TTL_MINUTES ?? 15)
};
