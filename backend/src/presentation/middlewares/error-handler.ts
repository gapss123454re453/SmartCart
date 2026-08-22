import type { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";
import { HttpError } from "../../models/http-error.js";

export function errorHandler(error: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (error instanceof ZodError) {
    return res.status(400).json({ message: "Entrada invalida.", issues: error.flatten() });
  }

  if (error instanceof HttpError) {
    return res.status(error.statusCode).json({ message: error.message });
  }

  console.error(error);
  return res.status(500).json({ message: "Erro interno." });
}
