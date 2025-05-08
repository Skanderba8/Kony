// jest.config.mjs
export default {
    testEnvironment: "jsdom",
    transform: {
      "^.+\\.(js|jsx)$": "babel-jest"
    },
    // This is crucial for Firebase ESM modules
    transformIgnorePatterns: [
      "node_modules/(?!(@firebase|firebase)/)"
    ],
    moduleNameMapper: {
      "\\.(css|less|scss|sass)$": "identity-obj-proxy",
      "\\.(jpg|jpeg|png|gif|svg)$": "<rootDir>/__mocks__/fileMock.js"
    },
    testMatch: ["**/__tests__/**/*.js", "**/?(*.)+(spec|test).js"],
    // No setupFilesAfterEnv to avoid require issues
  }