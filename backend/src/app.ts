import express from "express";
import cors from "cors";
import helmet from "helmet";
import { authRoutes } from "./presentation/controllers/auth.routes.js";
import { productRoutes } from "./presentation/controllers/product.routes.js";
import { cartRoutes } from "./presentation/controllers/cart.routes.js";
import { sessionRoutes } from "./presentation/controllers/session.routes.js";
import { validationRoutes } from "./presentation/controllers/validation.routes.js";
import { paymentTokenRoutes } from "./presentation/controllers/payment-token.routes.js";
import { exitRoutes } from "./presentation/controllers/exit.routes.js";
import { errorHandler } from "./presentation/middlewares/error-handler.js";

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get("/health", (_req, res) => res.json({ status: "ok" }));
app.use("/auth", authRoutes);
app.use("/products", productRoutes);
app.use("/carts", cartRoutes);
app.use("/sessions", sessionRoutes);
app.use("/validations", validationRoutes);
app.use("/payment-tokens", paymentTokenRoutes);
app.use("/exit", exitRoutes);

app.use(errorHandler);
