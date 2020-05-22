import * as React from 'react'
import { Button } from 'react-bootstrap'
import axios from 'axios';
import { AxiosResponse } from 'axios';
import AxiosHelper from '../utils/AxiosHelper'

interface Statement {
  id: number,
  content: string
}

interface Individual {
  id: number,
  name: string,
  picture_url: string
}
interface Agreement {
  id: number,
  statement: Statement,
  reason: string,
  extent: number // 100 agree; 0 disagree
}

interface GameProps {
  agreements: Agreement[],
  individual: Individual
}

interface GameState {
  answers: number[], // 100 agree, 50 skip, 0 disagree
  currentQuestion: number
}

export class GameComponent extends React.Component<GameProps, GameState>{
  constructor(props: GameProps) {
    super(props)

    this.state = {
      answers: [],
      currentQuestion: 0
    }
  }

  vote = (answer: number) => {
    const { answers, currentQuestion } = this.state
    const { individual, agreements } = this.props
    answers[currentQuestion] = answer
    this.setState({ answers: answers, currentQuestion: currentQuestion + 1 })
    const event_args = {
      name: "vote",
      statement_id: agreements[currentQuestion].statement.id,
      game_individual_id: individual.id,
      extent: answer
    }
    AxiosHelper()
    axios.post('/api/v2/events', event_args)
  }

  render() {
    const { agreements, individual } = this.props
    const { currentQuestion } = this.state

    const count = agreements.length
    return (
      <div>
        <div className="game-wrap">
          <div className="game-picture">
            <img src={individual.picture_url} alt={`${individual.name} photo`} />
          </div>
          <div className="game-question">
            <h1>Do you agree with {individual.name}?</h1>
          </div>
        </div>
        <h5>Vote to see {individual.name}'s opinions:</h5>
        <h2>{currentQuestion + 1}. {agreements[currentQuestion].statement.content}</h2>
        <p>Do you agree?</p>
        <Button variant="success" className="game-agree" onClick={() => this.vote(100)}>Agree</Button>
        <Button variant="danger" onClick={() => this.vote(0)}>Disagree</Button>
        <Button variant="link" onClick={() => this.vote(50)}>Skip</Button>
      </div>
    )
  }
}

export default GameComponent
