
db.movies.countDocuments({
    type: "movie",
    genres: "Comedy"
})



db.movies.find({
  type: "movie",
  year: 1932,
  $or: [
    {genres: "Drama"},
    {languages: "French"}
  ]
})



db.movies.find({
  type: "movie",
  year: {
    $gte: 2012,
    $lte: 2014
  },
  "awards.wins": {
    $gte: 5,
    $lte: 9
  },
  countries: "USA"
  })



db.comments.aggregate([
  {
    $match: {
      email: /.*gameofthron.es.*/
    }
  },
  {
    $group: {
      _id: null,
      total_comentarios: {
        $sum: 1
      }
    }
  }
])



db.comments.aggregate([
  {
    $match: {
      email: /.*gameofthron.es.*/
    }
  },
  {
    $group: {
      _id: "$email",
      contador: {
        $sum: 1
      }
    }
  },
  {
    $sort: {
      contador: -1
    }
  }
])



db.theaters.aggregate([
  {
    $match: {
      "location.address.state": "DC"
    }
  },
  {
    $group: {
      _id: "$location.address.zipcode",
      contador: {
        $sum: 1
      }
    }
  }
])



db.movies.find({
  type: "movie",
  directors: "John Landis",
  "imdb.rating": {
    $gte: 7.5,
    $lte: 8
  }
})
