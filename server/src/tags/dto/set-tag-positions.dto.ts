import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsNotEmpty,
  IsString,
  Matches,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  MAX_POSITIONS_PER_REQUEST,
  ORDER_KEY_PATTERN,
} from '../../common/ordering/order-key';

export class TagPositionDto {
  @IsString()
  @IsNotEmpty()
  id: string;

  // null takes the tag out of the order (it goes back to name order).
  @ValidateIf((_, value) => value !== null)
  @IsString()
  @Matches(ORDER_KEY_PATTERN)
  position: string | null;
}

export class SetTagPositionsDto {
  @IsArray()
  @ArrayMaxSize(MAX_POSITIONS_PER_REQUEST)
  @ValidateNested({ each: true })
  @Type(() => TagPositionDto)
  positions: TagPositionDto[];
}
