import 'api_error.dart';

sealed class ApiResult<T> {
  const ApiResult();
  factory ApiResult.success(T data) = ApiSuccess<T>;
  factory ApiResult.failure(ApiError error) = ApiFailure<T>;
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);
}

class ApiFailure<T> extends ApiResult<T> {
  final ApiError error;
  const ApiFailure(this.error);
}
