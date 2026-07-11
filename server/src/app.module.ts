import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { DictionaryModule } from './dictionary/dictionary.module';
import { GaugeRecordsModule } from './gauge-records/gauge-records.module';
import { GaugeTargetsModule } from './gauge-targets/gauge-targets.module';
import { HealthModule } from './health/health.module';
import { LibraryModule } from './library/library.module';
import { PatternsModule } from './patterns/patterns.module';
import { ProfileModule } from './profile/profile.module';
import { ProjectsModule } from './projects/projects.module';
import { SkillsModule } from './skills/skills.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    AuthModule,
    DatabaseModule,
    DictionaryModule,
    GaugeRecordsModule,
    GaugeTargetsModule,
    HealthModule,
    LibraryModule,
    ProfileModule,
    ProjectsModule,
    PatternsModule,
    SkillsModule,
  ],
})
export class AppModule {}
