import { Router } from "express";
import { prisma } from "../../services/prisma.js";
import { requireAuth } from "../middlewares/auth.js";
import { HttpError } from "../../models/http-error.js";

export const productRoutes = Router();

productRoutes.use(requireAuth);

productRoutes.get("/", async (_req, res) => {
  const products = await prisma.product.findMany({
    where: { active: true },
    orderBy: { name: "asc" },
    take: 200
  });
  return res.json(products);
});

productRoutes.get("/barcode/:barcode", async (req, res, next) => {
  try {
    const product = await prisma.product.findFirst({
      where: { barcode: req.params.barcode, active: true },
      include: { retailerEvidence: { orderBy: { retailerName: "asc" } } }
    });
    if (!product) throw new HttpError(404, "Produto nao cadastrado.");
    return res.json(product);
  } catch (error) {
    return next(error);
  }
});
