import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class MagicLoginDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(128)
  code: string;
}
