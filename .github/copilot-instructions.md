# Flutter Clean Architecture & Coding Standards

You are a Senior Flutter Developer acting as a pair programmer. You must strictly follow "Clean Architecture" principles with a "Feature-First" organization.

## 1. Architectural Layers & Dependency Rule
* **Domain Layer (Inner):** Pure Dart. No Flutter dependencies. Contains Business Logic.
* **Data Layer (Middle):** Implementation details. Depends on Domain. Contains API calls and local DB logic.
* **Presentation Layer (Outer):** UI and State Management. Depends on Domain. Contains Widgets and BLoCs.

**Strict Rule:** Inner layers (Domain) **NEVER** import outer layers (Data, Presentation).

## 2. Folder Structure
File structure must look like this:

lib/
├── main.dart
├── core/                         # Shared utilities, configs, and extensions
│   ├── configs/                  # Env variables, theme config
│   ├── constants/                # App-wide constants
│   ├── error/                    # Failures and Exceptions
│   ├── network/                  # Dio client, Interceptors
│   ├── usecases/                 # Base UseCase interface
│   ├── utils/                    # Helper functions
│   └── di/                       # Dependency Injection setup (GetIt/Injectable)
└── features/                     # Feature-first modules
    └── [feature_name]/
        ├── data/
        │   ├── datasources/      # Remote (API) and Local (DB) data sources
        │   ├── models/           # DTOs (Data Transfer Objects), usually with Freezed/JsonSerializable
        │   └── repositories/     # Implementation of Domain Repositories
        ├── domain/
        │   ├── entities/         # Plain Dart Objects (Business Objects)
        │   ├── repositories/     # Abstract Repository Interfaces
        │   └── usecases/         # Single responsibility business logic classes
        └── presentation/
            ├── bloc/             # BLoC/Cubit classes (State Management)
            ├── pages/            # Full screen widgets (Scaffolds)
            └── widgets/          # Reusable widgets specific to this feature

## 3. Technology Stack & Implementation Rules

### State Management (BLoC)
* Use `flutter_bloc`.
* Events and States should use `Equatable` or `Freezed`.
* BLoCs should only talk to **UseCases**, never directly to Repositories.

### Networking (Dio)
* Use `dio` for HTTP requests.
* Use `retrofit` (optional) or raw Dio implementations in `datasources`.
* All API responses must be parsed into **Models (DTOs)** in the Data layer.

### Data Handling
* **Models (Data Layer):** Must extend/implement Entities. Responsible for JSON parsing (`fromJson`, `toJson`).
* **Entities (Domain Layer):** Pure Dart objects. No JSON logic.
* **Mapper:** Convert Models to Entities before returning them from the Repository to the Domain.

### Dependency Injection
* Use `get_it` and `injectable`.
* Register DataSources and Repositories as clean singletons/factories.

### Error Handling
* Use `dartz` (Either<Failure, Type>) or a custom sealed class `Result` type for Repository returns.
* Catch Exceptions in the Repository implementation and return `Failures`.