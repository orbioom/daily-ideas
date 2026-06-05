/* seed.js — realistic starter library for Stacks
 * ~14 well-known books across 3 shelves, with ratings/reviews and sessions.
 * Exposes window.StacksSeed.build() -> normalized state.
 */
(function (global) {
  "use strict";

  function isoDaysAgo(days) {
    var d = new Date();
    d.setHours(12, 0, 0, 0);
    d.setDate(d.getDate() - days);
    return d.toISOString();
  }

  function dateDaysAgo(days) {
    return isoDaysAgo(days).slice(0, 10);
  }

  function build() {
    var shelves = [
      { id: "shelf_fiction", name: "Modern Fiction", description: "Novels and literary fiction worth revisiting.", color: "#5B6CA8" },
      { id: "shelf_scifi", name: "Science Fiction", description: "Speculative futures and far worlds.", color: "#5E8C8C" },
      { id: "shelf_nonfic", name: "Nonfiction & Ideas", description: "Big ideas, science, and how the world works.", color: "#C7A36B" }
    ];

    var books = [
      {
        id: "book_dune", title: "Dune", author: "Frank Herbert", year: 1965,
        pageCount: 688, genre: "Science Fiction", coverColor: "#C7A36B",
        status: "finished", currentPage: 688, rating: 5,
        review: "A staggering act of world-building. The ecology, politics, and prophecy braid together into something that still feels singular decades later.",
        shelfIds: ["shelf_scifi"], dateAdded: isoDaysAgo(220), dateFinished: isoDaysAgo(180)
      },
      {
        id: "book_left_hand", title: "The Left Hand of Darkness", author: "Ursula K. Le Guin", year: 1969,
        pageCount: 304, genre: "Science Fiction", coverColor: "#5E8C8C",
        status: "finished", currentPage: 304, rating: 5,
        review: "Le Guin uses a frozen world to thaw our assumptions about gender and loyalty. Quietly radical and beautifully written.",
        shelfIds: ["shelf_scifi"], dateAdded: isoDaysAgo(160), dateFinished: isoDaysAgo(120)
      },
      {
        id: "book_neuromancer", title: "Neuromancer", author: "William Gibson", year: 1984,
        pageCount: 271, genre: "Science Fiction", coverColor: "#3A3E4C",
        status: "finished", currentPage: 271, rating: 4,
        review: "Dense, neon, and prophetic. The prose moves like the city it describes.",
        shelfIds: ["shelf_scifi"], dateAdded: isoDaysAgo(140), dateFinished: isoDaysAgo(110)
      },
      {
        id: "book_threebody", title: "The Three-Body Problem", author: "Cixin Liu", year: 2008,
        pageCount: 400, genre: "Science Fiction", coverColor: "#5B6CA8",
        status: "reading", currentPage: 210, rating: 0, review: "",
        shelfIds: ["shelf_scifi"], dateAdded: isoDaysAgo(40), dateFinished: ""
      },
      {
        id: "book_beloved", title: "Beloved", author: "Toni Morrison", year: 1987,
        pageCount: 324, genre: "Literary Fiction", coverColor: "#B07C8E",
        status: "finished", currentPage: 324, rating: 5,
        review: "Haunting in the most literal and figurative sense. Morrison's sentences carry an entire history of grief.",
        shelfIds: ["shelf_fiction"], dateAdded: isoDaysAgo(200), dateFinished: isoDaysAgo(150)
      },
      {
        id: "book_neverwhere", title: "Neverwhere", author: "Neil Gaiman", year: 1996,
        pageCount: 372, genre: "Fantasy", coverColor: "#9A6E8E",
        status: "want-to-read", currentPage: 0, rating: 0, review: "",
        shelfIds: ["shelf_fiction"], dateAdded: isoDaysAgo(18), dateFinished: ""
      },
      {
        id: "book_kavalier", title: "The Amazing Adventures of Kavalier & Clay", author: "Michael Chabon", year: 2000,
        pageCount: 639, genre: "Literary Fiction", coverColor: "#8B6F5E",
        status: "reading", currentPage: 95, rating: 0, review: "",
        shelfIds: ["shelf_fiction"], dateAdded: isoDaysAgo(30), dateFinished: ""
      },
      {
        id: "book_neverlet", title: "Never Let Me Go", author: "Kazuo Ishiguro", year: 2005,
        pageCount: 288, genre: "Literary Fiction", coverColor: "#7A8CA0",
        status: "finished", currentPage: 288, rating: 4,
        review: "A slow ache of a novel. Restraint is the whole point, and it lands.",
        shelfIds: ["shelf_fiction"], dateAdded: isoDaysAgo(95), dateFinished: isoDaysAgo(70)
      },
      {
        id: "book_road", title: "The Road", author: "Cormac McCarthy", year: 2006,
        pageCount: 287, genre: "Literary Fiction", coverColor: "#565A70",
        status: "abandoned", currentPage: 120, rating: 0, review: "",
        shelfIds: ["shelf_fiction"], dateAdded: isoDaysAgo(60), dateFinished: ""
      },
      {
        id: "book_sapiens", title: "Sapiens: A Brief History of Humankind", author: "Yuval Noah Harari", year: 2011,
        pageCount: 443, genre: "History", coverColor: "#C7A36B",
        status: "finished", currentPage: 443, rating: 4,
        review: "Sweeping and provocative. Best read as a set of arguments to wrestle with, not gospel.",
        shelfIds: ["shelf_nonfic"], dateAdded: isoDaysAgo(130), dateFinished: isoDaysAgo(100)
      },
      {
        id: "book_thinking", title: "Thinking, Fast and Slow", author: "Daniel Kahneman", year: 2011,
        pageCount: 499, genre: "Psychology", coverColor: "#6E7BB0",
        status: "reading", currentPage: 260, rating: 0, review: "",
        shelfIds: ["shelf_nonfic"], dateAdded: isoDaysAgo(25), dateFinished: ""
      },
      {
        id: "book_immortal", title: "The Immortal Life of Henrietta Lacks", author: "Rebecca Skloot", year: 2010,
        pageCount: 381, genre: "Science", coverColor: "#86C79A",
        status: "finished", currentPage: 381, rating: 5,
        review: "An ethics seminar disguised as a page-turner. Skloot keeps the human story front and center.",
        shelfIds: ["shelf_nonfic"], dateAdded: isoDaysAgo(115), dateFinished: isoDaysAgo(85)
      },
      {
        id: "book_emperor", title: "The Emperor of All Maladies", author: "Siddhartha Mukherjee", year: 2010,
        pageCount: 571, genre: "Science", coverColor: "#5E8C8C",
        status: "want-to-read", currentPage: 0, rating: 0, review: "",
        shelfIds: ["shelf_nonfic"], dateAdded: isoDaysAgo(10), dateFinished: ""
      },
      {
        id: "book_educated", title: "Educated", author: "Tara Westover", year: 2018,
        pageCount: 334, genre: "Memoir", coverColor: "#B07C8E",
        status: "finished", currentPage: 334, rating: 5,
        review: "A memoir about the cost and the gift of leaving. Unforgettable.",
        shelfIds: ["shelf_nonfic"], dateAdded: isoDaysAgo(105), dateFinished: isoDaysAgo(75)
      }
    ];

    // Reading sessions — including a current streak over the last several days.
    var sessions = [
      // Three-Body Problem — active reading, recent consecutive days
      { id: "sess_3b_1", bookId: "book_threebody", date: dateDaysAgo(4), pagesRead: 38, minutes: 45, note: "The countdown chapters." },
      { id: "sess_3b_2", bookId: "book_threebody", date: dateDaysAgo(3), pagesRead: 42, minutes: 50, note: "" },
      { id: "sess_3b_3", bookId: "book_threebody", date: dateDaysAgo(2), pagesRead: 30, minutes: 35, note: "The VR game sequences." },
      { id: "sess_3b_4", bookId: "book_threebody", date: dateDaysAgo(1), pagesRead: 36, minutes: 40, note: "" },
      { id: "sess_3b_5", bookId: "book_threebody", date: dateDaysAgo(0), pagesRead: 24, minutes: 30, note: "Lunch break chapter." },
      // Thinking, Fast and Slow
      { id: "sess_tk_1", bookId: "book_thinking", date: dateDaysAgo(6), pagesRead: 40, minutes: 55, note: "Anchoring and availability." },
      { id: "sess_tk_2", bookId: "book_thinking", date: dateDaysAgo(2), pagesRead: 35, minutes: 40, note: "" },
      // Kavalier & Clay
      { id: "sess_kc_1", bookId: "book_kavalier", date: dateDaysAgo(5), pagesRead: 50, minutes: 60, note: "The escape from Prague." },
      { id: "sess_kc_2", bookId: "book_kavalier", date: dateDaysAgo(1), pagesRead: 45, minutes: 50, note: "" },
      // A finished book, historical session
      { id: "sess_du_1", bookId: "book_dune", date: dateDaysAgo(182), pagesRead: 90, minutes: 100, note: "Arrival on Arrakis." }
    ];

    return global.StacksStorage.normState({
      version: 1,
      books: books,
      shelves: shelves,
      sessions: sessions,
      settings: { theme: "system", defaultSort: "dateAdded", density: "comfortable", view: "grid" },
      seeded: true
    });
  }

  global.StacksSeed = { build: build };
})(window);
