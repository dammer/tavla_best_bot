/* eslint no-console:0 */

// Rails Unobtrusive JavaScript (UJS) is *required* for links in Lucky that use DELETE, POST and PUT.
// Though it says "Rails" it actually works with any framework.
require("@rails/ujs").start();

// Turbolinks is optional. Learn more: https://github.com/turbolinks/turbolinks/
require("turbolinks").start();

// import anime from "animejs/lib/anime.es";


let socket;
if (!socket && !with_bot) {
  socket = new WebSocket(`${ws_endpoint}`);
}

// If using Turbolinks, you can attach events to page load like this:
//
document.addEventListener("turbolinks:load", function() {

  function reloadGame() {
    Turbolinks.clearCache();
    Turbolinks.visit(window.location, {"action": "replace"})
  }

  if (socket) {
    socket.onopen = function(e) {
      setInterval(() => {
        socket.send("" + Math.random());
      }, period);
    };

    socket.onmessage = function(event) {
      console.log("last: " + player_last_action + " edata: " + event.data)
      if (ws) {
        if (event.data[0] != "*" && player_last_action != event.data) {
          ws = false;
          reloadGame();
        }
      }
    };

    socket.onclose = function(event) {
      console.log((`closed: ${event.code}`));
      reloadGame();
    };

    socket.onerror = function(error) {
      console.log(error.message);
      reloadGame();
    };
  }

  var dices_s0 = new Audio('/assets/audio/dice0.mp3');
  var dices_s1 = new Audio('/assets/audio/dice1.mp3');
  var update_form = document.querySelector("#update_form");

  // звук броска
  var dices_sound = function () {
    if (state == "wait_dice_roll") {
      if (Math.random() < 0.5){
        dices_s0.play();
      }else{
        dices_s1.play();
      }
    }
  }

  const board_width = 210;

  var text_box = document.querySelector("#message_text");

  // ход по клику на инф сообщение
  var message_form = document.querySelector('#message_form');

  if (message_form) {
    message_form.onclick = function(){
      if (submit_count > 0 || !turn )
      {
        return;
      }
      loader_on();
      submit_count = submit_count + 1;
      update_form.click();
      dices_sound();
    };
  }

  function autoTurnBot() {
    if (submit_count > 0) { return; }
    loader_on()
    submit_count = submit_count + 1;
    update_form.click();
    dices_sound();
  }

  var total_wait = 1.5
  if (message_form) {
    if (!turn && with_bot) {
      setTimeout(autoTurnBot, total_wait * 1000);
      loader_on();
    }
  }

  // && with_bot == true;
  if (message_form && turn && state == 'wait_transfer_turn' && player_action == 'no_movies_left') {
    setTimeout(autoTurnBot, total_wait * 1000);
    loader_on();
  }


  // выравнивает текст сообщения по центру
  function align_text(){
    if (text_box){
      text_box.setAttribute(
        "x", (board_width - text_box.getBBox().width)/2
      );
    }
  };

  align_text();

  var svg = document.querySelector("svg");

  function svg_waiting(){
    if (svg) {
      svg.classList.add("waiting-message");
    }
  }

  if (document.querySelector("svg #layer4")){
    svg_waiting();
  }

  var loader = document.querySelector("#loader");

  function loader_on() {
    if (loader) {
      loader.classList.add("loader");
    }
  }

  // анимация направления
  //
  var tr_idx = 0;
  var tr_timer;
  var iter = 0
  if (turn && !message_form && first_turn) {
    tr_idx = player > 0 ? 0 : 23;
    tr_timer = setInterval(function() {
      set_hl(tr_idx, "fade")
      tr_idx = tr_idx + player;
      iter = iter + 1
      if (iter >= 24) {
        clearInterval(tr_timer);
      }
    }, 25);
  }

  function get_tr(idx) {
    return document.querySelector(`[data-triangle='${idx}']`)
  }

  function set_hl(idx, _klass) {
    tr = get_tr(idx);
    if (tr) {
      tr.classList.add(_klass);
    }
  }

  // проверка выбран источник и кость и ход на сервер если да
  function submit_if_ready() {
    if (submit_count > 0)
    {
      return;
    }
    var cell = document.querySelector(".is-active-cell");
    if (!cell) { return };
    var dice = document.querySelector(".is-active-dice");
    if (!dice) { return };

    // svg_waiting();
    loader_on();

    add_update_param("score", dice.dataset["value"]);
    add_update_param("index", cell.id);
    update_form.click();
  };

  function attr(obj, name){
    return obj.getAttribute(name);
  };

  function add_update_param(name, value) {
    update_form.dataset["params"] += ("&" + name + "=" + value);
  };

  // выбор стартовой фишки и ход про выбраной кости
  var cells = document.querySelectorAll('.can_move');
  cells.forEach(cell => {
    cell.addEventListener("click", function () {
      cells.forEach(el => {
        el.classList.remove("is-active-cell");
      });
      cell.classList.toggle("is-active-cell");
      submit_if_ready();
    });
  });

  // выбор кости, ход по выбору кости
  var dices = document.querySelectorAll('.dice:not(.used_dice)');
  dices.forEach(dice => {
    dice.addEventListener("click", function () {
      deselec_dices()
      dice.classList.toggle("is-active-dice");
      submit_if_ready();
    });
  });

  function deselec_dices(){
    dices.forEach(el => {
      el.classList.remove("is-active-dice");
    });
  };

  function cell_idx(cell) {
    return parseInt(cell.parentElement.dataset["idx"]);
  };

  // можем очистить выбор кости если клик на свободно место на доске
  var board_bgs = document.querySelectorAll('.half_board_bg');
  board_bgs.forEach(item => {
    item.addEventListener("click", deselec_dices);
  });


  // ход выбраной фишкой по месту назначения
  var dests = document.querySelectorAll('.dest')
  dests.forEach(dest => {
    dest.addEventListener("click", function () {
      if (submit_count > 0)
      {
        return;
      }
      var src = document.querySelector('.is-active-cell')
      if (!src) { return; }
      var src_idx = cell_idx(src);
      var dest_idx = cell_idx(dest);
      if (dest_idx == 25) {
        dest_idx = 24
      }
      if (dest_idx == -2) {
        dest_idx = -1
      }
      var sc = Math.max(src_idx, dest_idx) - Math.min(src_idx, dest_idx);
      dices.forEach(dice => {
        if (parseInt(dice.dataset["value"]) === sc) {
          dice.dispatchEvent(new MouseEvent('click',{}));
          submit_count = submit_count + 1;
        };
      });
    });
  });

  var link = document.querySelector('#ad_offer_send')

  function set_adv_handler() {
    if (link) {
      link.addEventListener('ajax:success', function(evt, data, status, xhr){
        console.log('success:', evt);
        console.log('success:', data);
        console.log('success:', status);
        console.log('success:', xhr);
      })
      link.addEventListener('ajax:error',function(xhr, status, error){
        console.log('failed:', xhr);
        console.log('failed:', status);
        console.log('failed:', error);
      });
    }
  };

  set_adv_handler();

})

