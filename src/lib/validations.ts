import { z } from 'zod'

export const slugSchema = z
  .string()
  .min(2, 'Mínimo 2 caracteres')
  .max(100, 'Máximo 100 caracteres')
  .regex(/^[a-z0-9-]+$/, 'Use apenas letras minúsculas, números e hífens')

export const emailSchema = z.string().email('E-mail inválido').min(1, 'E-mail é obrigatório')

export const organizationSchema = z.object({
  trade_name: z.string().min(2, 'Nome fantasia é obrigatório').max(200),
  legal_name: z.string().max(200).optional().or(z.literal('')),
  slug: slugSchema,
  document_number: z.string().optional().or(z.literal('')),
  email: z.string().email('E-mail inválido').optional().or(z.literal('')),
  phone: z.string().optional().or(z.literal('')),
})

export const operationSchema = z.object({
  name: z.string().min(2, 'Nome é obrigatório').max(200),
  slug: slugSchema,
  description: z.string().max(1000).optional().or(z.literal('')),
  operation_type: z.string().optional().or(z.literal('')),
})

export const salesLocationSchema = z.object({
  name: z.string().min(2, 'Nome é obrigatório').max(200),
  slug: slugSchema,
  location_type: z.string().min(1, 'Tipo é obrigatório'),
  shopping_name: z.string().optional().or(z.literal('')),
  address_line: z.string().optional().or(z.literal('')),
  city: z.string().optional().or(z.literal('')),
  state_code: z.string().max(2, 'Use a sigla do estado (ex: SP)').optional().or(z.literal('')),
})

export const teamSchema = z.object({
  name: z.string().min(2, 'Nome é obrigatório').max(200),
  description: z.string().optional().or(z.literal('')),
  operation_id: z.string().uuid('Selecione uma operação'),
  sales_location_id: z.string().uuid('Selecione um PDV').optional().or(z.literal('')),
  supervisor_member_id: z.string().uuid().optional().or(z.literal('')),
})

export const inviteUserSchema = z.object({
  email: emailSchema,
  full_name: z.string().min(2, 'Nome é obrigatório').max(200),
  role: z.enum(['director', 'supervisor', 'salesperson'], {
    errorMap: () => ({ message: 'Selecione um perfil' }),
  }),
})

export const profileUpdateSchema = z.object({
  full_name: z.string().min(2, 'Nome é obrigatório').max(200),
  preferred_name: z.string().max(100).optional().or(z.literal('')),
  phone: z.string().max(20).optional().or(z.literal('')),
})
