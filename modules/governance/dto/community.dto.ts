import { IsEnum, IsNotEmpty, IsOptional, IsString, IsBoolean, IsArray } from 'class-validator';
import { CaseCategory, ChannelType } from '@prisma/client';

export class CreateChannelDto {
    @IsString()
    @IsNotEmpty()
    administrativeUnitId!: string;

    @IsEnum(CaseCategory)
    @IsOptional()
    category?: CaseCategory;

    @IsEnum(ChannelType)
    @IsOptional()
    type?: ChannelType;

    @IsString()
    @IsNotEmpty()
    name!: string;
}

export class CreateMessageDto {
    @IsString()
    @IsNotEmpty()
    content!: string;

    @IsString()
    @IsNotEmpty()
    channelId!: string;

    @IsString()
    @IsNotEmpty()
    authorId!: string;

    @IsBoolean()
    @IsOptional()
    isOfficial?: boolean;

    @IsString()
    @IsOptional()
    replyToId?: string;

    @IsOptional()
    @IsArray()
    attachments?: any[];
}

export class JoinChannelDto {
    @IsString()
    @IsNotEmpty()
    userId!: string;

    @IsString()
    @IsNotEmpty()
    channelId!: string;
}

import { z } from 'zod';

export const CreateMessageSchema = z.object({
    content: z.string().min(1),
    channelId: z.string().min(1), // Changed from uuid() to accept CUIDs
    isOfficial: z.boolean().optional(),
    replyToId: z.string().optional(),
    attachments: z.array(z.any()).optional()
});

