/// Sealed result type returned by every [IActionModule.execute] call.
///
/// The UI layer pattern-matches on this to decide what to display and speak.
/// Raw exceptions must NEVER bubble up past a module boundary.
sealed class CommandResult {
  const CommandResult();
}

/// The action completed successfully.
class Success extends CommandResult {
  /// What the TTS engine should say to the user.
  final String speechResponse;

  /// Optional structured payload for the UI (e.g. weather data, contact list).
  final Map<String, dynamic>? data;

  const Success({required this.speechResponse, this.data});
}

/// Alias for Success result.
typedef ActionSuccess = Success;

/// A recoverable error occurred inside the module.
class ActionError extends CommandResult {
  /// Short, friendly sentence shown to / spoken to the user.
  final String userFriendlyMessage;

  /// Technical detail for logs — never shown in the UI.
  final String? technicalDetail;

  const ActionError({
    required this.userFriendlyMessage,
    this.technicalDetail,
  });
}

/// The action was blocked because a required permission was denied.
class PermissionDenied extends CommandResult {
  /// The human-readable name of the missing permission.
  final String permissionName;

  const PermissionDenied(this.permissionName);

  String get speechResponse =>
      'I need $permissionName permission to do that. '
      'Please grant it in your device settings.';
}

/// A named entity (contact, app, note, etc.) could not be found.
class NotFound extends CommandResult {
  final String entity;

  const NotFound(this.entity);

  String get speechResponse => "I couldn't find $entity.";
}

/// A network or backend request failed.
class NetworkFailure extends CommandResult {
  final String? detail;

  const NetworkFailure({this.detail});

  String get speechResponse =>
      'I could not reach the server. Please check your internet connection.';
}

/// Extension to quickly extract a speech string from any result.
extension CommandResultX on CommandResult {
  String get speechResponse => switch (this) {
        Success s => s.speechResponse,
        ActionError e => e.userFriendlyMessage,
        PermissionDenied p => p.speechResponse,
        NotFound n => n.speechResponse,
        NetworkFailure f => f.speechResponse,
      };

  bool get isSuccess => this is Success;
}
