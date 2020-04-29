const supportedFabricVersions = ['1.4.3', '1.4.4'];
const supportFabrikkaVersions = ['alpha-0.0.1'];

function validationBase(condition, errorMessage, emitFn) {
  if (condition) {
    emitFn('error', new Error(errorMessage));
  }
}

function validateFabrikkaVersion(fabrikkaVersion, emitFn) {
  validationBase(
    !supportFabrikkaVersions.includes(fabrikkaVersion),
    `Fabrikka's ${fabrikkaVersion} version is not supported. Supported versions are: ${supportFabrikkaVersions}`,
    emitFn,
  );
}

function validateFabricVersion(fabricVersion, emitFn) {
  validationBase(
    !supportedFabricVersions.includes(fabricVersion),
    `Fabric's ${fabricVersion} version is not supported. Supported versions are: ${supportedFabricVersions}`,
    emitFn,
  );
}

function validateOrderer(orderer, emitFn) {
  validationBase(
    (orderer.consensus === 'solo' && orderer.instances > 1),
    `Orderer consesus type is set to 'solo', but number of instances is ${orderer.instances}. Only one instance is needed :).`,
    emitFn,
  );
}

module.exports = {
  validateFabrikkaVersion,
  validateFabricVersion,
  validateOrderer,
};
