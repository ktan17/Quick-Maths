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
    let containerStyle = {
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      width: '100vw',
      height: '100vh'
    };
    let digitStyle = {
      fontSize: '20em'
    };

    return (
      <div style={containerStyle}>
        <p style={digitStyle}>{this.state.digit}</p> 
      </div>
    );
  }
}

export default App;
