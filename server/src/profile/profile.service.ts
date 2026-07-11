import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { ProfileResponseDto, toProfileResponse } from './profile-response.dto';
import { SaveProfileDto } from './profile-save.dto';

@Injectable()
export class ProfileService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrentProfile(ownerId: string): Promise<ProfileResponseDto> {
    const profile = await this.prisma.userProfile.upsert({
      where: { id: ownerId },
      create: {
        id: ownerId,
        displayName: ownerId,
        preferredUnits: 'Metric',
      },
      update: {},
    });

    return toProfileResponse(profile);
  }

  async updateCurrentProfile(
    ownerId: string,
    body: SaveProfileDto,
  ): Promise<ProfileResponseDto> {
    const data = this.toProfileData(body);

    const profile = await this.prisma.userProfile.upsert({
      where: { id: ownerId },
      create: {
        id: ownerId,
        ...data,
      },
      update: {
        ...data,
        deletedAt: null,
      },
    });

    return toProfileResponse(profile);
  }

  private toProfileData(body: SaveProfileDto) {
    const displayName = body.displayName.trim();
    const preferredUnits = body.preferredUnits.trim();

    if (!displayName || !preferredUnits) {
      throw new BadRequestException({
        code: 'VALIDATION_FAILED',
        message: 'Display name and preferred units are required.',
      });
    }

    return {
      displayName,
      preferredUnits,
    };
  }
}
