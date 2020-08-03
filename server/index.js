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

app.get('/4sec/:fileName', (request, response) => {
  const { fileName } = request.params
  console.log('Serving', fileName)
  fs.createReadStream('dataset/4sec/' + fileName).pipe(response)
})

app.get('/4sec/:filePath/:fileName', (request, response) => {
  const { filePath, fileName } = request.params
  console.log('Serving', filePath, fileName)
  fs.createReadStream('dataset/4sec/' + filePath + '/' + fileName).pipe(response)
})

app.listen(8080, () => {
  console.log('Listening on port 80')
})
