import { Router } from "express";
import { z } from "zod";
import { CartStatus, PaymentTokenStatus, ShoppingSessionStatus, ValidationStatus } from "@prisma/client";
import { prisma } from "../../services/prisma.js";
import { requireAuth } from "../middlewares/auth.js";
import { env } from "../../services/env.js";
import { validateWeight } from "../../domain/services/weight-validation.js";
import { createExitToken, hashToken } from "../../services/token.js";
import { HttpError } from "../../models/http-error.js";

export const validationRoutes = Router();

validationRoutes.use(requireAuth);

validationRoutes.get("/pending", async (_req, res) => {
  const sessions = await prisma.shoppingSession.findMany({
    where: { status: ShoppingSessionStatus.PENDING_VALIDATION },
    include: {
      user: { select: { id: true, name: true, email: true } },
      cart: true,
      items: { include: { product: true } }
    },
    orderBy: { finishedAt: "asc" }
  });
  return res.json(sessions);
});

validationRoutes.post("/:sessionId", async (req, res, next) => {
  try {
    const { measured_weight_grams } = z.object({
      measured_weight_grams: z.number().int().min(0)
    }).parse(req.body);

    const result = await prisma.$transaction(async (tx) => {
      const session = await tx.shoppingSession.findUnique({
        where: { id: req.params.sessionId },
        include: { cart: true, validation: true }
      });

      if (!session || session.status !== ShoppingSessionStatus.PENDING_VALIDATION) {
        throw new HttpError(404, "Compra pendente nao encontrada.");
      }

      const check = validateWeight(
        session.expectedWeightGrams,
        measured_weight_grams,
        env.weightTolerancePercentage
      );

      const validation = await tx.validation.upsert({
        where: { sessionId: session.id },
        update: {
          expectedWeightGrams: session.expectedWeightGrams,
          measuredWeightGrams: measured_weight_grams,
          differenceGrams: check.differenceGrams,
          tolerancePercentage: env.weightTolerancePercentage,
          status: check.approved ? ValidationStatus.APPROVED : ValidationStatus.REJECTED,
          validatedAt: new Date()
        },
        create: {
          sessionId: session.id,
          expectedWeightGrams: session.expectedWeightGrams,
          measuredWeightGrams: measured_weight_grams,
          differenceGrams: check.differenceGrams,
          tolerancePercentage: env.weightTolerancePercentage,
          status: check.approved ? ValidationStatus.APPROVED : ValidationStatus.REJECTED
        }
      });

      const nextStatus = check.approved
        ? ShoppingSessionStatus.APPROVED
        : ShoppingSessionStatus.REQUIRES_ASSISTANCE;

      await tx.shoppingSession.update({
        where: { id: session.id },
        data: { status: nextStatus }
      });

      await tx.cart.update({
        where: { id: session.cartId },
        data: { status: CartStatus.AVAILABLE }
      });

      let rawToken: string | null = null;
      if (check.approved) {
        rawToken = createExitToken();
        await tx.paymentToken.upsert({
          where: { sessionId: session.id },
          update: {
            tokenHash: hashToken(rawToken),
            status: PaymentTokenStatus.ACTIVE,
            expiresAt: new Date(Date.now() + env.exitTokenTtlMinutes * 60_000),
            usedAt: null
          },
          create: {
            sessionId: session.id,
            tokenHash: hashToken(rawToken),
            expiresAt: new Date(Date.now() + env.exitTokenTtlMinutes * 60_000)
          }
        });
      }

      return { validation, status: nextStatus, token: rawToken };
    });

    return res.json(result);
  } catch (error) {
    return next(error);
  }
});
