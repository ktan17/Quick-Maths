import React, { Component } from 'react';
import openSocket from 'socket.io-client';
const socket = openSocket('http://localhost:8080');

function subscribe(cb) {
  socket.on('digit', digit => cb(digit));
}

class App extends Component {
  state = { digit: 0 }

  constructor(props) {
    super(props)

    subscribe(digit => this.setState({
      digit: digit
    }));
  }

  render() {
    return (
      <p>{this.state.digit}</p>
    );
  }
}

export default App;
