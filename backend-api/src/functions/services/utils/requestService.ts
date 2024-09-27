import { errorResult, Result, successResult } from "../../utils/result";

export const getBearerTokenFromHeader = (
  authorizationHeader: string | undefined,
): Result<string> => {
  if (authorizationHeader == null) {
    return errorResult({
      errorMessage: "No Authentication header present",
      errorCategory: "CLIENT_ERROR",
    });
  }

  if (!authorizationHeader.startsWith("Bearer ")) {
    return errorResult({
      errorMessage:
        "Invalid authentication header format - does not start with Bearer",
      errorCategory: "CLIENT_ERROR",
    });
  }

  if (authorizationHeader.split(" ").length !== 2) {
    return errorResult({
      errorMessage: "Invalid authentication header format - contains spaces",
      errorCategory: "CLIENT_ERROR",
    });
  }

  const jwe = authorizationHeader.split(" ")[1];

  if (jwe.length == 0) {
    return errorResult({
      errorMessage: "Invalid authentication header format - missing token",
      errorCategory: "CLIENT_ERROR",
    });
  }

  return successResult(jwe);
};
