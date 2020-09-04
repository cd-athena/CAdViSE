const express = require('express')
const fs = require('fs')
const app = express()

app.use((request, response, next) => {
  response.header('Access-Control-Allow-Origin', '*')
  response.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept')
  next()
})

app.get('/ping', (request, response) => {
  console.log('Pinged!')
  response.send('pong')
})

app.get('/:title/:fileName', (request, response) => {
  const { title, fileName } = request.params
  console.log('Serving', title, fileName)
  fs.createReadStream('dataset/' + title + '/' + fileName).pipe(response)
})

app.get('/:title/:filePath/:fileName', (request, response) => {
  const { title, filePath, fileName } = request.params
  console.log('Serving', title, filePath, fileName)
  fs.createReadStream('dataset/' + title + '/' + filePath + '/' + fileName).pipe(response)
})

app.listen(80, () => {
  console.log('Listening on port 80')
})
