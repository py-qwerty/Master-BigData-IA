// 1. Analizar la colección
use ('movies')


db.movies.find().limit(5)

// 2. Contar documentos
db.movies.countDocuments()

// 3. Insertar una película
db.movies.insertOne({
    title: "Como matar a tu dragón",
    year: 2024,
    cast: ["Paco de Lucía", "Manuel Carrasco"],
    genres: ["Drama"]
})
db.movies.find({title: "Como matar a tu dragón" })

// 4. Borrar la película insertada
db.movies.deleteOne({ title: "Como matar a tu dragón" })

// 5. Contar películas con "and" en el array cast
 db.movies.countDocuments({ cast: "and" })


// 6. Eliminar "and" del array cast
var query_where = { cast: "and" };              
var query_update = { $pull: { cast: "and" } }; 
db.movies.updateMany(query_where, query_update);

// 7. Contar películas con el array cast vacío
var query = { cast: { $size: 0 }}
db.movies.countDocuments(query)

// 8. Añadir "Undefined" a cast si está vacío
var query_where = { cast: { $size: 0 } };
var query_update = { $set: { cast: ['Undefined' ] } };
db.movies.updateMany(
    query_where,
    query_update
)

// 9. Contar películas con el array genres vacío
var query = { genres: { $size : 0} };
db.movies.countDocuments(query)

// 10. Añadir "Undefined" a genres si está vacío
var query_where = { genres: { $size : 0} };
var query_update = { $set: { genres: ["Undefined"] } };
db.movies.updateMany(
     query_where,
    query_update
)

// 11. Mostrar el año más reciente
var query_group = { $group: { _id: null, year: { $max: "$year" } } };
var query_project = { $project: { _id: 0, year: 1 } };

db.movies.aggregate([ query_group, query_project ]);
// 12. Contar películas de los últimos 20 años
// 1. Agrupar todo en un solo documento y calcular el año actual
var query_group = {
    $group: {
        _id: null  // Agrupar todos los documentos en uno solo
    }
};

// 2. Proyecto para calcular el año actual y los últimos 20 años
var query_project_current = {
    $project: {
        _id: 0,
        currentYear: { $year: new Date() },  // Obtener el año actual
        last20Years: { $subtract: [{ $year: new Date() }, 20] }  // Restar 20 años al año actual
    }
};

// 3. Lookup para contar películas desde hace 20 años
var query_lookup_current = {
    $lookup: {
        from: "movies",  // Colección de origen
        pipeline: [
            { $match: { year: { $gte: new Date().getFullYear() - 20 } } }, // Películas desde hace 20 años
            { $count: "total" }  // Contar cuántas películas cumplen la condición
        ],
        as: "recentMovies"
    }
};

// 4. Proyectar la salida final con el conteo de películas
var query_project_output = {
    $project: {
        _id: null,
        total: { $arrayElemAt: ["$recentMovies.total", 0] }  // Extraer el conteo de 'recentMovies'
    }
};

// Ejecución
db.movies.aggregate([
    query_group,            // Agrupar para evitar múltiples resultados
    query_project_current,  // Calcular el año actual y los últimos 20 años
    query_lookup_current,   // Realizar el conteo desde hace 20 años
    query_project_output    // Formatear la salida
]);






// 13. Mostrar el año más reciente
  var query_match = { $match: { year: { $gte: 1960, $lte: 1969 } } };
    var query_count =  { $count: "total" };
    db.movies.aggregate([
     query_match,
     query_count
    ])
// 14. Contar películas de los últimos 20 años
var query_group  = { $group: { _id: "$year", pelis: { $sum: 1 } } };
var sort = { $sort: { pelis: -1 } };
var limit = { $limit: 1 };

db.movies.aggregate([
    query_group,
    sort,
    limit
])

// 15. Contar películas de la década de los 60
var query_match = { $match: { year: { $gte: 1960, $lte: 1969 } } };
var query_count =  { $count: "total" };
db.movies.aggregate([
 query_match,
 query_count
])

// 16. Año(s) con más películas

var query_group  = { $group: { _id: "$year", total: { $sum: 1 } } };
var sort = { $sort: { total: -1 } };
var limit = { $limit: 1 };

db.movies.aggregate([
    query_group,
    sort,
    limit
])

// 15. Año(s) con menos películas
var query_group  =  { $group: { _id: "$year", total: { $sum: 1 } } };
var sort = { $sort: { total: 1 } };
var limit = { $limit: 1 };


db.movies.aggregate([
    query_group,
    sort,
    limit
])

// 16. Guardar en nueva colección 'actors' usando $unwind

var unbundle = { $unwind: "$cast" };  // Descomponer el array 'cast'

// Generar un nuevo _id único usando $function y ObjectId
var generate_new_id = {
    $addFields: { 
        _id: { 
            $function: {
                body: function() { return ObjectId(); },  // Generar un nuevo ObjectId
                args: [], 
                lang: "js"
            }
        }
    }
};

// Guardar en la nueva colección 'actors'
var new_collection = { $out: "actors" };

db.movies.aggregate([
    unbundle,          // Descomponer el array 'cast'
    generate_new_id,   // Generar nuevos _id únicos
    new_collection     // Guardar el resultado en 'actors'
]);

// Contar los documentos en la nueva colección
db.actors.countDocuments();



// 17. Top 5 actores con más películas (excluyendo "Undefined")
var remove_undefined =  { $match: { cast: { $ne: "Undefined" } } };
var group = { $group: { _id: "$cast", cuenta: { $sum: 1 } } };
var sort = { $sort: { cuenta: -1 } };
var limit =  { $limit: 5 }

db.actors.aggregate([
    remove_undefined, 
    group, 
    sort, 
    limit
])

// 18. Top 5 películas con más actores
var group_and_count = { $group: { _id: { title: "$title", year: "$year" }, cuenta: { $sum: 1 } } };
var sort = { $sort: { cuenta: -1 } };
var limit =  { $limit: 5 }

db.actors.aggregate([
    group_and_count,
    sort,
   limit
])

// 19. Top 5 actores con la carrera más larga
var remove_undefined =  { $match: { cast: { $ne: "Undefined" } } };
var group_by_actor = { $group: { 
        _id: "$cast", 
        comienza: { $min: "$year" },
        termina: { $max: "$year" }
    }};
var proyection = { $project: { 
        _id: 1, 
        años: { $subtract: ["$termina", "$comienza"] },
        comienza: 1,
        termina: 1
    }};
    var sort_desc = { $sort: { años: -1 } };
    var limit_five = { $limit: 5}
    
db.actors.aggregate([
    remove_undefined,
    group_by_actor,
    proyection,
    sort_desc,
    limit_five
])

// 20. Guardar en nueva colección 'genres' usando $unwind
var unbundle = { $unwind: "$genres" };  // Descomponer el array 'cast'

// Generar un nuevo _id único usando $function y ObjectId
var generate_new_id = {
    $addFields: { 
        _id: { 
            $function: {
                body: function() { return ObjectId(); },  // Generar un nuevo ObjectId
                args: [], 
                lang: "js"
            }
        }
    }
};

// Guardar en la nueva colección 'actors'
var new_collection = { $out: "genres" };

db.movies.aggregate([
    unbundle,          // Descomponer el array 'cast'
    generate_new_id,   // Generar nuevos _id únicos
    new_collection     // Guardar el resultado en 'actors'
]);

// Contar los documentos en la nueva colección
db.genres.countDocuments();


// 21. Top 5 "Año y Género" con más películas
db.genres.aggregate([
    { $group: { _id: { year: "$year", genre: "$genres" }, pelis: { $sum: 1 } } },
    { $sort: { pelis: -1 } },
    { $limit: 5 }
])

// 22. Top 5 actores con más géneros diferentes
db.genres.aggregate([
    { $match: { cast: { $ne: "Undefined" } } },
    { $group: { _id: "$cast", generos: { $addToSet: "$genres" } } },
    { $project: { numgeneros: { $size: "$generos" }, generos: 1 } },
    { $sort: { numgeneros: -1 } },
    { $limit: 5 }
])

// 23. Top 5 películas con más géneros diferentes
db.genres.aggregate([
    { $group: { _id: { title: "$title", year: "$year" }, generos: { $addToSet: "$genres" } } },
    { $project: { numgeneros: { $size: "$generos" }, generos: 1 } },
    { $sort: { numgeneros: -1 } },
    { $limit: 5 }
])

// 24. Query libre: Top 5 años con más películas de género "Drama"


db.genres.aggregate([
    { $match: { genres: "Drama" } },
    { $group: { _id: "$year", pelis: { $sum: 1 } } },
    { $sort: { pelis: -1 } },
    { $limit: 5 }
])

// 25. Query libre: Top 5 actores que trabajaron en películas de género "Action"
db.genres.aggregate([
    { $match: { genres: "Action" } },
    { $group: { _id: "$cast", num_peliculas_drama: { $sum: 1 } } },
    { $sort: { num_peliculas_drama: -1 } },
    { $limit: 5 }
])

// 26. Query libre: Contar cuántas películas tienen más de 3 géneros
db.genres.aggregate([
    { $group: { _id: { title: "$title", year: "$year" }, genres: { $addToSet: "$genres" } } },
    { $match: {$expr: { $gt: [ { $size: "$genres" }, 3 ] }}},
    { $count: "totalMovies" }
])
