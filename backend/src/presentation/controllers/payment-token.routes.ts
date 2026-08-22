import { Router } from "express";
import { PaymentTokenStatus, ShoppingSessionStatus } from "@prisma/client";
import { prisma } from "../../services/prisma.js";
import { requireAuth } from "../middlewares/auth.js";
import { HttpError } from "../../models/http-error.js";

export const paymentTokenRoutes = Router();

paymentTokenRoutes.use(requireAuth);

paymentTokenRoutes.get("/:sessionId", async (req, res, next) => {
  try {
    const session = await prisma.shoppingSession.findFirst({
      where: {
        id: req.params.sessionId,
        userId: req.user!.id,
        status: ShoppingSessionStatus.APPROVED
      },
      include: { paymentToken: true }
    });

    if (!session?.paymentToken || session.paymentToken.status !== PaymentTokenStatus.ACTIVE) {
      throw new HttpError(404, "Token de saida nao disponivel.");
    }

    return res.json({
      sessionId: session.id,
      status: session.paymentToken.status,
      expiresAt: session.paymentToken.expiresAt
    });
  } catch (error) {
    return next(error);
  }
});
