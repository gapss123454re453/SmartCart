import { Router } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { prisma } from "../../services/prisma.js";
import { env } from "../../services/env.js";
import { requireAuth } from "../middlewares/auth.js";
import { HttpError } from "../../models/http-error.js";

export const authRoutes = Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(6)
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1)
});

function publicUser(user: { id: string; name: string; email: string; createdAt: Date }) {
  return { id: user.id, name: user.name, email: user.email, createdAt: user.createdAt };
}

authRoutes.post("/register", async (req, res, next) => {
  try {
    const data = registerSchema.parse(req.body);
    const passwordHash = await bcrypt.hash(data.password, 12);
    const user = await prisma.user.create({
      data: { name: data.name, email: data.email.toLowerCase(), passwordHash }
    });
    return res.status(201).json(publicUser(user));
  } catch (error: any) {
    if (error?.code === "P2002") return next(new HttpError(409, "Email ja cadastrado."));
    return next(error);
  }
});

authRoutes.post("/login", async (req, res, next) => {
  try {
    const data = loginSchema.parse(req.body);
    const user = await prisma.user.findUnique({ where: { email: data.email.toLowerCase() } });
    if (!user || !(await bcrypt.compare(data.password, user.passwordHash))) {
      throw new HttpError(401, "Email ou senha invalidos.");
    }

    const token = jwt.sign({ id: user.id, email: user.email }, env.jwtSecret, {
      expiresIn: env.jwtExpiresIn as jwt.SignOptions["expiresIn"]
    });

    return res.json({ token, user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

authRoutes.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.user.findUniqueOrThrow({ where: { id: req.user!.id } });
    return res.json(publicUser(user));
  } catch (error) {
    return next(error);
  }
});
