import { Router } from "express";
import { z } from "zod";
import { CartStatus, ShoppingSessionStatus } from "@prisma/client";
import { prisma } from "../../services/prisma.js";
import { requireAuth } from "../middlewares/auth.js";
import { HttpError } from "../../models/http-error.js";

export const cartRoutes = Router();

cartRoutes.use(requireAuth);

cartRoutes.post("/link", async (req, res, next) => {
  try {
    const { cart_code } = z.object({ cart_code: z.string().min(3) }).parse(req.body);

    const session = await prisma.$transaction(async (tx) => {
      const existingUserSession = await tx.shoppingSession.findFirst({
        where: { userId: req.user!.id, status: ShoppingSessionStatus.ACTIVE }
      });
      if (existingUserSession) throw new HttpError(409, "Voce ja possui uma compra ativa.");

      const cart = await tx.cart.findUnique({ where: { code: cart_code } });
      if (!cart || cart.status !== CartStatus.AVAILABLE) {
        throw new HttpError(409, "Este carrinho nao esta disponivel.");
      }

      await tx.cart.update({ where: { id: cart.id }, data: { status: CartStatus.IN_USE } });

      return tx.shoppingSession.create({
        data: { userId: req.user!.id, cartId: cart.id },
        include: { cart: true, items: { include: { product: true } } }
      });
    });

    return res.status(201).json(session);
  } catch (error) {
    return next(error);
  }
});

cartRoutes.get("/:id", async (req, res, next) => {
  try {
    const cart = await prisma.cart.findUnique({ where: { id: req.params.id } });
    if (!cart) throw new HttpError(404, "Carrinho nao encontrado.");
    return res.json(cart);
  } catch (error) {
    return next(error);
  }
});
