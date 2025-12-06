# Camera Connect - Clean Architecture

This project follows **Clean Architecture** principles with a **Feature-First** folder organization.

## 📁 Project Structure

```
lib/
├── main.dart                         # App entry point
├── core/                             # Shared utilities, configs, and extensions
│   ├── constants/                    # App-wide constants
│   │   └── app_constants.dart
│   ├── error/                        # Failures and Exceptions
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── usecases/                     # Base UseCase interface
│   │   └── usecase.dart
│   ├── utils/                        # Helper functions
│   │   └── logger.dart
│   └── di/                           # Dependency Injection setup (GetIt)
│       └── injection_container.dart
└── features/                         # Feature-first modules
    └── camera/                       # Camera feature
        ├── data/                     # Data Layer
        │   ├── datasources/          # Remote (API) and Local (DB) data sources
        │   │   ├── camera_remote_data_source.dart
        │   │   └── camera_local_data_source.dart
        │   ├── models/               # DTOs (Data Transfer Objects)
        │   │   ├── camera_model.dart
        │   │   ├── image_model.dart
        │   │   └── log_entry_model.dart
        │   └── repositories/         # Implementation of Domain Repositories
        │       └── camera_repository_impl.dart
        ├── domain/                   # Domain Layer
        │   ├── entities/             # Plain Dart Objects (Business Objects)
        │   │   ├── camera.dart
        │   │   ├── image.dart
        │   │   ├── connection_status.dart
        │   │   └── log_entry.dart
        │   ├── repositories/         # Abstract Repository Interfaces
        │   │   └── camera_repository.dart
        │   └── usecases/             # Single responsibility business logic
        │       ├── connect_to_camera.dart
        │       ├── disconnect_camera.dart
        │       ├── discover_cameras.dart
        │       ├── download_image.dart
        │       ├── get_camera_images.dart
        │       └── get_connection_status.dart
        └── presentation/             # Presentation Layer
            ├── bloc/                 # BLoC classes (State Management)
            │   ├── camera_bloc.dart
            │   ├── camera_event.dart
            │   └── camera_state.dart
            ├── pages/                # Full screen widgets (Scaffolds)
            └── widgets/              # Reusable widgets specific to this feature
```

## 🏗️ Architecture Layers

### 1. Domain Layer (Inner - Pure Dart)
- **No Flutter dependencies**
- Contains business logic
- **Entities**: Pure Dart objects representing business concepts
- **Repositories**: Abstract interfaces (contracts)
- **Use Cases**: Single responsibility business logic classes

### 2. Data Layer (Middle)
- Depends on Domain Layer
- **Models**: DTOs with JSON serialization logic
- **Data Sources**: 
  - Remote: Platform channel communication (PTP/IP)
  - Local: Cache/storage (placeholder for now)
- **Repository Implementations**: Concrete implementations of domain repositories

### 3. Presentation Layer (Outer)
- Depends on Domain Layer (NOT on Data Layer)
- **BLoC**: State management using flutter_bloc
- **Pages**: Full screen widgets
- **Widgets**: Reusable UI components

## 📦 Dependencies

### Core Dependencies
- **flutter_bloc**: State management
- **equatable**: Value equality
- **dartz**: Functional programming (Either type for error handling)
- **get_it**: Dependency injection
- **injectable**: Code generation for DI
- **dio**: HTTP client (for future API calls)

### Dev Dependencies
- **injectable_generator**: Code generation for DI
- **build_runner**: Build system

## 🔄 Data Flow

```
UI (Widget) 
  ↓
BLoC (Events/States)
  ↓
Use Case (Business Logic)
  ↓
Repository Interface (Contract)
  ↓
Repository Implementation
  ↓
Data Source (Platform Channels)
```

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Dependency Injection
The app uses `get_it` for dependency injection. All dependencies are registered in `lib/core/di/injection_container.dart`.

The DI container is initialized in `main.dart`:
```dart
await di.init();
```

### 3. Using BLoC
BLoCs are provided at the app level in `main.dart` using `MultiBlocProvider`:

```dart
BlocProvider(
  create: (context) => di.sl<CameraBloc>()..add(InitializeCameraEvent()),
)
```

## 📝 Key Principles

### Dependency Rule
- **Inner layers NEVER import outer layers**
- Domain Layer is pure Dart (no Flutter)
- Data Layer can import Domain
- Presentation Layer can import Domain (but NOT Data directly)

### Error Handling
- Use `Either<Failure, Type>` from `dartz` for repository returns
- Catch Exceptions in Repository and return Failures
- BLoC handles Failures and emits appropriate states

### State Management
- BLoCs only talk to Use Cases
- Events trigger Use Cases
- States represent UI state
- Use `Equatable` for Events and States

## 🔧 Adding New Features

1. Create feature folder in `lib/features/`
2. Create domain layer (entities, repositories, use cases)
3. Create data layer (models, data sources, repository implementation)
4. Create presentation layer (bloc, pages, widgets)
5. Register dependencies in `injection_container.dart`

## 📱 Platform Channels

The app communicates with native code via platform channels:
- **Method Channel**: `com.tanzo.camera/ptp` - For method invocations
- **Event Channel**: `com.tanzo.camera/ptp_events` - For streaming events

## 🎯 Next Steps

- [ ] Migrate existing widgets to use BLoC
- [ ] Create presentation layer pages
- [ ] Implement error handling UI
- [ ] Add loading indicators
- [ ] Implement local caching
- [ ] Add unit tests for each layer
- [ ] Add integration tests

## 📚 Additional Resources

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter BLoC Documentation](https://bloclibrary.dev/)
- [GetIt Documentation](https://pub.dev/packages/get_it)
- [Dartz Documentation](https://pub.dev/packages/dartz)
