//=============================================================================
// CannonPhaseFix.js — CANNONに飛び込んだ瞬間の向きズレ修正（非公式MOD）
//=============================================================================
/*:
 * @plugindesc [Unofficial MOD] Fixes CANNON turning an extra 90 degrees when entered right after it rotates.
 * @author UNKO TECHNICA unofficial MOD
 *
 * @help
 * 【不具合】CANNONが回転したのと同じフレームに飛び込むと、1フレーム後にもう90°回ってしまう。
 * 【原因】飛び込んだときにイベントのページが切り替わり、ツクールMVが移動ルートを
 *   最初の命令（90°回転）からやり直すため。回転した直後の1フレームだけは
 *   「次はウェイト」を指しているので、ウェイトが飛ばされて余計に回る。
 * 【修正】CANNON（コモンイベント104を呼ぶイベント）だけを対象に、ページが切り替わっても
 *   移動ルートの命令の並びが同じなら、ルートの続きから動かす。
 *   ウェイト中（残り時間がある）の場合は何もしない。公式で別の方法の修正が入っても、
 *   二重に補正しないようにするため。
 *
 * [Bug] Entering a rotating CANNON on the exact frame it rotates makes it turn one extra step.
 * [Fix] Keep the move-route position across the page switch (CANNON events only).
 */
(function() {
    'use strict';
    var CANNON_CE = 104;

    function isCannon(ev) {
        var data = ev.event();
        return !!(data && data.pages.some(function(p) {
            return p.list.some(function(c) { return c.code === 117 && c.parameters[0] === CANNON_CE; });
        }));
    }

    function codesOf(route) {
        return route && route.list ? route.list.map(function(c) { return c.code; }).join(',') : null;
    }

    var _setupPageSettings = Game_Event.prototype.setupPageSettings;
    Game_Event.prototype.setupPageSettings = function() {
        var oldRoute = this._moveRoute, oldIndex = this._moveRouteIndex, oldWait = this._waitCount;
        _setupPageSettings.call(this);
        if (oldRoute && oldWait === 0 && oldIndex > 0 && isCannon(this) &&
                codesOf(oldRoute) === codesOf(this._moveRoute) && oldIndex < this._moveRoute.list.length) {
            this._moveRouteIndex = oldIndex;
        }
    };
})();
