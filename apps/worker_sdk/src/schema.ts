import { z } from "zod";

export const paramsCompletionSchema = z.object({
  model: z.string(),
  messages: z.array(
    z.object({
      role: z.string(),
      content: z.string(),
    }),
  ),
  stream: z.boolean().default(false),
  temperature: z.number().default(0.0),
});

// When we have different types of params we can use this
// export const paramsSchema = z.union([
//   paramsCompletionSchema
// ]);
export const paramsSchema = paramsCompletionSchema;

export const requestSchema = z.object({
  id: z.string(),
  params: paramsSchema,
});
