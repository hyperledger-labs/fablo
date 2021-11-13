const assert = require('assert');
const repositoryUtils = require('../generators/repositoryUtils');

describe('versionSort', () => {
  it('should sort versions', () => {
    // Given
    const unsortedVersions = [
      '0.0.2',
      '0.0.1',
      '0.1.11',
      '0.1.1',
      '1.21.2',
    ];

    // When
    const sortedVersions = repositoryUtils.sortVersions(unsortedVersions);

    // Then
    const expectedVersions = [
      '1.21.2',
      '0.1.11',
      '0.1.1',
      '0.0.2',
      '0.0.1',
    ];
    assert.deepEqual(sortedVersions, expectedVersions);
  });
});
