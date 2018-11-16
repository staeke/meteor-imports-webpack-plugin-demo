import React from 'react';

export default class HelloWorld extends React.Component {
    constructor() {
        super();
        this.state = {counter: 0};
        this.onClick = () => {
            this.setState({counter: this.state.counter + 1});
        };
    }

    render() {
        return <div>
            <button onClick={this.onClick}>Click Me</button>
            <p>You've pressed the button {this.state.counter} times.</p>
        </div>;
    }

}