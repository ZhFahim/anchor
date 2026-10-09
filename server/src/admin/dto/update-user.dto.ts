import {
  IsBoolean,
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { RejectUnknownFields } from '../../common/decorators/reject-unknown-fields.decorator';

@RejectUnknownFields()
export class UpdateUserDto {
  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsNotEmpty()
  @IsString()
  @Transform(({ value }: { value: string }) => value?.trim())
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsBoolean()
  isAdmin?: boolean;
}
