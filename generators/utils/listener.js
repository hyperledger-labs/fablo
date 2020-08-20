class Listener {
  constructor() {
    this.messages = [];
  }

  onEvent(event) {
    this.messages.push(event);
  }

  getAllMessages() {
    return this.messages;
  }

  count() {
    return this.messages.length;
  }
}

module.exports = Listener;
