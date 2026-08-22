import { Router } from "express";
import { z } from "zod";
import { CartStatus, ShoppingSessionStatus } from "@prisma/client";
import { prisma } from "../../services/prisma.js";
import { requireAuth } from "../middlewares/auth.js";
import { HttpError } from "../../models/http-error.js";
import { recalculateSessionTotals } from "../../domain/services/totals.js";

export const sessionRoutes = Router();

sessionRoutes.use(requireAuth);

const sessionInclude = {
  cart: true,
  items: { include: { product: true }, orderBy: { createdAt: "asc" as const } },
  validation: true,
  paymentToken: true
};

async function getOwnedSession(sessionId: string, userId: string) {
  const session = await prisma.shoppingSession.findFirst({
    where: { id: sessionId, userId },
    include: sessionInclude
  });
  if (!session) throw new HttpError(404, "Compra nao encontrada.");
  return session;
}

sessionRoutes.post("/", async (_req, res) => {
  return res.status(400).json({ message: "Use /carts/link para iniciar uma compra." });
});

sessionRoutes.get("/current", async (req, res) => {
  const session = await prisma.shoppingSession.findFirst({
    where: { userId: req.user!.id, status: ShoppingSessionStatus.ACTIVE },
    include: sessionInclude
  });
  return res.json(session);
});

sessionRoutes.get("/history", async (req, res) => {
  const sessions = await prisma.shoppingSession.findMany({
    where: { userId: req.user!.id, status: { not: ShoppingSessionStatus.ACTIVE } },
    include: { cart: true, items: { include: { product: true } }, validation: true },
    orderBy: { createdAt: "desc" }
  });
  return res.json(sessions);
});

sessionRoutes.get("/:id/items", async (req, res, next) => {
  try {
    const session = await getOwnedSession(req.params.id, req.user!.id);
    return res.json(session.items);
  } catch (error) {
    return next(error);
  }
});

sessionRoutes.post("/:id/items", async (req, res, next) => {
  try {
    const { product_id, quantity } = z.object({
      product_id: z.string().uuid(),
      quantity: z.number().int().min(1)
    }).parse(req.body);

    await getOwnedSession(req.params.id, req.user!.id);
    const product = await prisma.product.findFirst({ where: { id: product_id, active: true } });
    if (!product) throw new HttpError(404, "Produto nao cadastrado.");

    const session = await prisma.$transaction(async (tx) => {
      const unitPrice = Number(product.price);
      const existing = await tx.shoppingItem.findUnique({
        where: { sessionId_productId: { sessionId: req.params.id, productId: product.id } }
      });
      const nextQuantity = (existing?.quantity ?? 0) + quantity;

      await tx.shoppingItem.upsert({
        where: { sessionId_productId: { sessionId: req.params.id, productId: product.id } },
        update: {
          quantity: nextQuantity,
          totalPrice: unitPrice * nextQuantity,
          totalWeightGrams: product.weightGrams * nextQuantity
        },
        create: {
          sessionId: req.params.id,
          productId: product.id,
          quantity,
          unitPrice,
          unitWeightGrams: product.weightGrams,
          totalPrice: unitPrice * quantity,
          totalWeightGrams: product.weightGrams * quantity
        }
      });

      return recalculateSessionTotals(tx, req.params.id);
    });

    return res.status(201).json(session);
  } catch (error) {
    return next(error);
  }
});

sessionRoutes.patch("/:id/items/:itemId", async (req, res, next) => {
  try {
    const { quantity } = z.object({ quantity: z.number().int().min(1) }).parse(req.body);
    await getOwnedSession(req.params.id, req.user!.id);

    const session = await prisma.$transaction(async (tx) => {
      const item = await tx.shoppingItem.findFirst({
        where: { id: req.params.itemId, sessionId: req.params.id }
      });
      if (!item) throw new HttpError(404, "Item nao encontrado.");

      await tx.shoppingItem.update({
        where: { id: item.id },
        data: {
          quantity,
          totalPrice: Number(item.unitPrice) * quantity,
          totalWeightGrams: item.unitWeightGrams * quantity
        }
      });
      return recalculateSessionTotals(tx, req.params.id);
    });

    return res.json(session);
  } catch (error) {
    return next(error);
  }
});

sessionRoutes.delete("/:id/items/:itemId", async (req, res, next) => {
  try {
    await getOwnedSession(req.params.id, req.user!.id);
    const session = await prisma.$transaction(async (tx) => {
      const deleted = await tx.shoppingItem.deleteMany({
        where: { id: req.params.itemId, sessionId: req.params.id }
      });
      if (deleted.count === 0) throw new HttpError(404, "Item nao encontrado.");
      return recalculateSessionTotals(tx, req.params.id);
    });
    return res.json(session);
  } catch (error) {
    return next(error);
  }
});

sessionRoutes.post("/:id/finish", async (req, res, next) => {
  try {
    const session = await getOwnedSession(req.params.id, req.user!.id);
    if (session.status !== ShoppingSessionStatus.ACTIVE) {
      throw new HttpError(409, "Compra nao esta ativa.");
    }
    if (session.items.length === 0) {
      throw new HttpError(400, "Adicione produtos antes de finalizar.");
    }

    const updated = await prisma.shoppingSession.update({
      where: { id: session.id },
      data: { status: ShoppingSessionStatus.PENDING_VALIDATION, finishedAt: new Date() },
      include: sessionInclude
    });
    return res.json(updated);
  } catch (error) {
    return next(error);
  }
});
