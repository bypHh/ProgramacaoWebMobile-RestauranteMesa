import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

async function bootstrap() {
  // Inicialização da aplicação NestJS
  const app = await NestFactory.create(AppModule);

  // Prefixo global para todas as rotas da API (ex: /api/auth/login)
  app.setGlobalPrefix('api');

  // Habilita CORS para permitir requisições do frontend web e do app Flutter (web/mobile/desktop)
  app.enableCors({
    origin: true,
    credentials: true,
  });

  // Validação global com class-validator
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Configuração da documentação Swagger
  const config = new DocumentBuilder()
    .setTitle('API Restaurante')
    .setDescription('Documentação da API')
    .setVersion('1.0')
    .addBearerAuth() // Permite informar o token JWT na interface
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  // Inicia o servidor em 0.0.0.0 para aceitar conexões do navegador, emulador Android (10.0.2.2) e dispositivos na rede local
  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');
  console.log(`Servidor rodando em http://localhost:${port}/api`);
  console.log(`Documentação em http://localhost:${port}/api/docs`);
}

bootstrap();