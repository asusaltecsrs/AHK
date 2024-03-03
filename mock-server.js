const express = require('express')
const bodyParser = require('body-parser')
const cors = require('cors')
const app = express()
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(cors())
const port = 3000

app.get('/user', (req, res) => {
  res.json({ get: 'Hello World!' })
})

app.post('/user', (req, res) => {
  const { body: { username } } = req
  console.log('username:', req.body)
  // res.json({ username })
  res.json(req.body)
  // res.json({ username: "mock" })
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
