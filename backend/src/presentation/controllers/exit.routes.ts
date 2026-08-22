import { Router } from "express";
import { z } from "zod";
import { PaymentTokenStatus, ShoppingSessionStatus } from "@prisma/client";
import { prisma } from "../../services/prisma.js";
import { hashToken } from "../../services/token.js";

export const exitRoutes = Router();

exitRoutes.post("/validate", async (req, res) => {
  const { token } = z.object({ token: z.string().min(6) }).parse(req.body);
  const tokenHash = hashToken(token);

  const paymentToken = await prisma.paymentToken.findUnique({
    where: { tokenHash },
    include: { session: true }
  });

  const denied = () => res.status(403).json({ status: "EXIT_DENIED" });

  if (!paymentToken) return denied();
  if (paymentToken.status !== PaymentTokenStatus.ACTIVE) return denied();
  if (paymentToken.expiresAt.getTime() < Date.now()) {
    await prisma.paymentToken.update({
      where: { id: paymentToken.id },
      data: { status: PaymentTokenStatus.EXPIRED }
    });
    return denied();
  }
  if (paymentToken.session.status !== ShoppingSessionStatus.APPROVED) return denied();

  await prisma.paymentToken.update({
    where: { id: paymentToken.id },
    data: { status: PaymentTokenStatus.USED, usedAt: new Date() }
  });

  return res.json({ status: "EXIT_ALLOWED" });
});
