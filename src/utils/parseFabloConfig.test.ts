import parseFabloConfig from "./parseFabloConfig";

describe("parseFabloConfig", () => {
  it("should parse valid JSON config", () => {
    const jsonConfig = `{
      "global": {
        "fabricVersion": "2.5.9",
        "tls": false,
        "engine": "docker"
      },
      "orgs": [
        {
          "organization": {
            "name": "Org1",
            "domain": "org1.example.com"
          }
        }
      ]
    }`;

    const result = parseFabloConfig(jsonConfig);
    
    expect(result).toEqual({
      global: {
        fabricVersion: "2.5.9",
        tls: false,
        engine: "docker"
      },
      orgs: [
        {
          organization: {
            name: "Org1",
            domain: "org1.example.com"
          }
        }
      ]
    });
  });

  it("should parse valid YAML config", () => {
    const yamlConfig = `
      global:
        fabricVersion: "2.5.9"
        tls: false
        engine: docker
      orgs:
        - organization:
            name: Org1
            domain: org1.example.com
    `;

    const result = parseFabloConfig(yamlConfig);

    expect(result).toEqual({
      global: {
        fabricVersion: "2.5.9",
        tls: false,
        engine: "docker"
      },
      orgs: [
        {
          organization: {
            name: "Org1",
            domain: "org1.example.com"
          }
        }
      ]
    });
  });

  it("should parse complex YAML config with multiple orgs and channels", () => {
    const yamlConfig = `
      global:
        fabricVersion: "2.4.7"
        tls: true
        engine: kubernetes
      orgs:
        - organization:
            name: Org1
            domain: org1.example.com
            peers:
              - name: peer0
                port: 7041
              - name: peer1
                port: 7042
        - organization:
            name: Org2 
            domain: org2.example.com
            peers:
              - name: peer0
                port: 8041
      channels:
        - name: mychannel
          orgs: ["Org1", "Org2"]
    `;

    const result = parseFabloConfig(yamlConfig);

    expect(result).toEqual({
      global: {
        fabricVersion: "2.4.7",
        tls: true,
        engine: "kubernetes"
      },
      orgs: [
        {
          organization: {
            name: "Org1",
            domain: "org1.example.com",
            peers: [
              {
                name: "peer0",
                port: 7041
              },
              {
                name: "peer1", 
                port: 7042
              }
            ]
          }
        },
        {
          organization: {
            name: "Org2",
            domain: "org2.example.com",
            peers: [
              {
                name: "peer0",
                port: 8041
              }
            ]
          }
        }
      ],
      channels: [
        {
          name: "mychannel",
          orgs: ["Org1", "Org2"]
        }
      ]
    });
  });

  it("should parse empty config", () => {
    const emptyConfig = `{}`;
    const result = parseFabloConfig(emptyConfig);
    expect(result).toEqual({});
  });
});
